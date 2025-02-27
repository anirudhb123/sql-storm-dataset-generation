
SELECT 
    u.DisplayName, 
    COUNT(p.Id) AS PostCount, 
    SUM(v.BountyAmount) AS TotalBounty
FROM 
    Users u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
GROUP BY 
    u.DisplayName
ORDER BY 
    PostCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
