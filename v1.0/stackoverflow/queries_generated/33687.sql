WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.PostCount,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;

WITH RecursiveVotes AS (
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        1 AS VoteLevel
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (2, 3) -- Only upvotes and downvotes
    UNION ALL
    SELECT 
        v.PostId,
        v.UserId,
        v.VoteTypeId,
        rv.VoteLevel + 1
    FROM 
        Votes v
    INNER JOIN 
        RecursiveVotes rv ON v.PostId = rv.PostId
    WHERE 
        rv.VoteLevel < 5 -- Limit recursion depth
)
SELECT 
    p.Id AS PostId,
    COUNT(rv.UserId) AS TotalVotes,
    SUM(CASE WHEN rv.VoteTypeId = 2 THEN 1 ELSE -1 END) AS NetVotes
FROM 
    Posts p
LEFT JOIN 
    RecursiveVotes rv ON p.Id = rv.PostId
GROUP BY 
    p.Id
HAVING 
    SUM(CASE WHEN rv.VoteTypeId = 2 THEN 1 ELSE -1 END) > 0
ORDER BY 
    TotalVotes DESC;

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE((SELECT COUNT(DISTINCT p.Id)
               FROM Posts p
               WHERE p.OwnerUserId = u.Id AND p.Score > 0), 0) AS PositivePostCount,
    COALESCE((SELECT SUM(b.Class)
               FROM Badges b
               WHERE b.UserId = u.Id), 0) AS TotalBadges
FROM 
    Users u
WHERE 
    u.CreationDate < DATEADD(MONTH, -6, GETDATE())
ORDER BY 
    u.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
