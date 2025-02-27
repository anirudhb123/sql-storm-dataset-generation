WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COALESCE(NULLIF(u.Reputation, 0), 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND (p.ViewCount > 100 OR u.Reputation > 50)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.Reputation
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        PostRank,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        UserReputation
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
FinalPosts AS (
    SELECT 
        tp.*,
        pt.Name AS PostTypeName
    FROM 
        TopPosts tp
    INNER JOIN 
        PostTypes pt ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    fp.UserReputation,
    fp.PostTypeName
FROM 
    FinalPosts fp
ORDER BY 
    fp.ViewCount DESC, 
    fp.UpVoteCount DESC
LIMIT 10;

WITH UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.CreationDate,
    ub.BadgeNames,
    ub.BadgeCount
FROM 
    Users u
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
WHERE 
    u.LastAccessDate >= NOW() - INTERVAL '6 months'
    AND (ub.BadgeCount IS NULL OR ub.BadgeCount > 2)
ORDER BY 
    u.Reputation DESC;

-- Find the ratio of accepted answers to total answers per user
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COUNT(a.Id) AS TotalAnswers,
    COUNT(qa.Id) AS AcceptedAnswers,
    CASE
        WHEN COUNT(a.Id) > 0 THEN ROUND(CAST(COUNT(qa.Id) AS FLOAT) / COUNT(a.Id), 2)
        ELSE 0
    END AS AcceptanceRate
FROM 
    Users u
LEFT JOIN 
    Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
LEFT JOIN 
    Posts qa ON a.AcceptedAnswerId = qa.Id
GROUP BY 
    u.Id, u.DisplayName
HAVING 
    COUNT(a.Id) > 0
ORDER BY 
    AcceptanceRate DESC
LIMIT 10;
