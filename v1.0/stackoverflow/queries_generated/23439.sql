WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        CASE 
            WHEN rp.RankByScore <= 3 THEN 'Top'
            ELSE 'Others'
        END AS PostRank
    FROM 
        RankedPosts rp
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.PostRank,
    COALESCE(b.Name, 'No Badge') AS BadgeName,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.PostId AND v.VoteTypeId IN (2, 3)) AS TotalVotes,
    (SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM 
        UNNEST(STRING_TO_ARRAY(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName)
     WHERE 
        p.Id = tp.PostId) AS AssociatedTags
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId 
                             FROM Posts p 
                             WHERE p.Id = tp.PostId 
                             LIMIT 1)
WHERE 
    tp.PostRank = 'Top'
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC
LIMIT 10;

-- Additional benchmark queries

-- Total Comments in last 30 days
WITH RecentComments AS (
    SELECT 
        COUNT(*) AS RecentCommentCount
    FROM 
        Comments 
    WHERE 
        CreationDate > NOW() - INTERVAL '30 days'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = u.Id) AS UserPostCount,
        (SELECT COUNT(*) FROM Comments WHERE UserId = u.Id) AS UserCommentCount,
        (SELECT COUNT(*) FROM Badges WHERE UserId = u.Id) AS UserBadgeCount
    FROM 
        Users u
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UserPostCount,
    us.UserCommentCount,
    us.UserBadgeCount,
    rc.RecentCommentCount
FROM 
    UserStats us
CROSS JOIN 
    RecentComments rc
WHERE 
    us.Reputation > 50
ORDER BY 
    us.UserPostCount DESC 
LIMIT 5;
