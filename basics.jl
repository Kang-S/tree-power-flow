function pk(;g=1,b=-10,vk=1,vm=1,pm=-1)
    # solve for pk given pm,vk,vm; ignores theta
    if g==0
        return -pm
    end
    temp = b^2*(-pm^2+(2*g*pm+(b^2+g^2)*vk^2)*vm^2-g^2*vm^4)
    temp < 0 ? NaN : 1/(b^2+g^2) * ((-b^2+g^2)*pm+g^3*(vk^2-vm^2)+b^2*g*(vk^2+vm^2)-2*g*temp^.5)
end

function pk_θ(;g=1,b=-10,vk=1,vm=1,pm=-1)
    # solve for pk, θkm given pm,vk,vm
    if g==0
        pk = -pm
        θ = -asin(pm/(b*vk*vm)) # maybe should check the argument here
        return pk, θ
    end
    disc = b^2*(-pm^2+(2*g*pm+(b^2+g^2)*vk^2)*vm^2-g^2*vm^4)
    if disc < 0 
        return NaN, NaN
    end
    pk = 1/(b^2+g^2) * ((-b^2+g^2)*pm+g^3*(vk^2-vm^2)+b^2*g*(vk^2+vm^2)-2*g*disc^.5)
    arg = (-g*pm+g^2*vm^2+disc^.5)/((b^2+g^2)*vk*vm)
    if arg > 1 arg = 1 end
    if arg < -1 arg = -1 end
    temp = -pm^2+(2*g*pm+g^2*vk^2)*vm^2-g^2*vm^4
    θ = temp > 0 ? acos(arg) : -acos(arg)
    pk, θ
end

function check(;g=1,b=-10,vk=1,vm=1,pk=.995,pm=-1,θ=-.1)
    # sanity check after a solution has been found
    pk_hat = g*(vk^2-vk*vm*cos(θ)) + b*vk*vm*sin(θ)
    pm_hat = g*(vm^2-vk*vm*cos(θ)) - b*vk*vm*sin(θ)
    err1 = pk_hat > 1e-6 ? abs((pk_hat-pk)/pk_hat) : abs(pk_hat-pk)
    err2 = pm_hat > 1e-6 ? abs((pm_hat-pm)/pm_hat) : abs(pm_hat-pm)
    maximum([err1, err2])
end

function check2(;g=1,b=-10,vk=1,vm=1,pk=.995,pm=-1,θ=-.1)
    # sanity check after a solution has been found
    pk_hat = g*(vk^2-vk*vm*cos(θ)) + b*vk*vm*sin(θ)
    pm_hat = g*(vm^2-vk*vm*cos(θ)) - b*vk*vm*sin(θ)
    err1 = abs(pk_hat) > 1e-6 ? abs((pk_hat-pk)/pk_hat) : abs(pk_hat-pk)
    err2 = abs(pm_hat) > 1e-6 ? abs((pm_hat-pm)/pm_hat) : abs(pm_hat-pm)
    err1, err2, pk_hat, pm_hat
end

function check_candidate(bus, candidate)
    function check_child(i)
        child = candidate.children[:,i]
        g = bus.children[i].g
        b = bus.children[i].b
        vk = candidate.v
        pkm, vm, d = child;
        pkm2, θ = pk_θ(g=g, b=b, vk=vk,vm=vm,pm=-d)
        check(g=g, b=b, pk=pkm, vk=vk, pm=-d, vm=vm, θ=θ)
    end
    candidate.n == 0 ? 0 : maximum(map(check_child, 1:candidate.n))
end

function check_bus(bus)
    cc(x) = check_candidate(bus, x)
    maximum(map(cc, values(bus.candidates)))
end

function check_all(bus_list)
    maximum(map(check_bus, bus_list))
end
