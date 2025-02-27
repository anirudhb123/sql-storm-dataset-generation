WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentRowNum
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FilteredEngagement AS (
    SELECT 
        ue.UserId,
        ue.Upvotes,
        ue.Downvotes,
        ue.GoldBadges,
        ue.SilverBadges,
        (ue.Upvotes - ue.Downvotes) AS NetEngagement,
        CASE 
            WHEN ue.Upvotes > 50 THEN 'High Engagement'
            WHEN ue.Upvotes BETWEEN 21 AND 50 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        UserEngagement ue
    WHERE 
        ue.Upvotes IS NOT NULL OR ue.Downvotes IS NOT NULL
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    p.CommentCount,
    fe.Upvotes,
    fe.Downvotes,
    fe.NetEngagement,
    fe.EngagementLevel
FROM 
    RankedPosts p
LEFT JOIN 
    FilteredEngagement fe ON p.PostId = (
        SELECT p2.Id
        FROM Posts p2
        WHERE p2.OwnerUserId = fe.UserId
        ORDER BY p2.Score DESC
        LIMIT 1
    )
WHERE 
    p.ScoreRank <= 5 AND 
    p.RecentRowNum <= 100
ORDER BY 
    p.Score DESC, 
    fe.NetEngagement DESC;

-- Complicated predicates & logic
WITH RecursiveTagRank AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS TagRank
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.Id, t.TagName
)
SELECT 
    tr.TagId,
    tr.TagName,
    tr.PostCount,
    CASE 
        WHEN tr.PostCount < 10 THEN 'Few Posts'
        WHEN tr.PostCount BETWEEN 10 AND 50 THEN 'Moderate Posts'
        ELSE 'Many Posts'
    END AS PostVolumeLevel
FROM 
    RecursiveTagRank tr
WHERE 
    tr.TagRank <= 20
ORDER BY 
    tr.PostCount DESC;
