
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ub.BadgeCount,
    (SELECT COUNT(*) FROM Posts p2 WHERE p2.OwnerUserId = ps.OwnerUserId) AS UserPostsCount,
    CASE 
        WHEN ps.UpVoteCount > ps.DownVoteCount THEN 'Positive'
        WHEN ps.UpVoteCount < ps.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS PostSentiment,
    COALESCE(t.TagName, 'No Tags') AS TagName
FROM 
    PostStats ps
LEFT JOIN 
    Users u ON ps.OwnerUserId = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    (SELECT Id, value AS TagName FROM Posts CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')) AS value) t ON ps.PostId = t.Id
WHERE 
    ps.UserPostRank <= 3
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
