-- Performance benchmarking query to analyze posts and their associated user activity

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Id AS UserId,
        u.DisplayName AS UserDisplayName,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.Id, u.DisplayName, u.Reputation
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.UserId,
    RP.UserDisplayName,
    RP.Reputation,
    RP.CommentCount,
    RP.UpVotes,
    RP.DownVotes
FROM 
    RankedPosts RP
WHERE 
    RP.RowNum <= 10  -- Limit to top 10 posts per PostType
ORDER BY 
    RP.CreationDate DESC;
