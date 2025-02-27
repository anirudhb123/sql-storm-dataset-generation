SELECT 
    p.Id AS PostID,
    p.Title,
    p.CreationDate,
    p.LastActivityDate,
    COUNT(c.Id) AS CommentCount,
    COUNT(v.Id) AS VoteCount,
    COALESCE(AVG(v.BountyAmount), 0) AS AverageBounty,
    u.DisplayName AS OwnerDisplayName,
    CASE
        WHEN p.Authorized = 1 THEN 'Yes'
        ELSE 'No'
    END AS IsAcceptedAnswer
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    p.Id, u.DisplayName
ORDER BY 
    p.LastActivityDate DESC;
