
WITH RecentPostsCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0
        END AS HasAcceptedAnswer
    FROM Posts p
    WHERE p.CreationDate >= CAST('2024-10-01' AS DATE) - 30
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0
        END AS HasAcceptedAnswer
    FROM Posts p
    JOIN RecentPostsCTE r ON r.PostId = p.ParentId
)

SELECT 
    u.DisplayName AS Author,
    p.Title,
    ISNULL(lt.Name, 'N/A') AS LinkType,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(v.BountyAmount) AS TotalBounty,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank,
    DATEDIFF(YEAR, p.CreationDate, GETDATE()) AS PostAge,
    CASE 
        WHEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) THEN 'More Upvotes'
        WHEN SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) < SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) THEN 'More Downvotes'
        ELSE 'Equal Votes'
    END AS VoteSummary
FROM Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Votes v ON p.Id = v.PostId
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
LEFT JOIN LinkTypes lt ON pl.LinkTypeId = lt.Id
LEFT JOIN Badges b ON u.Id = b.UserId
WHERE p.PostTypeId = 1
GROUP BY 
    u.Id, 
    p.Id, 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.OwnerUserId,
    lt.Name
HAVING 
    (CASE WHEN COUNT(DISTINCT c.Id) = 0 THEN 'No Comments' ELSE 'Has Comments' END) = 'Has Comments'
    AND SUM(v.BountyAmount) > 100
ORDER BY 
    PostRank,
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
