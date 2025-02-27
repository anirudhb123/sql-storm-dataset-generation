WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVoteCount,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
), RankPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY Score DESC) AS ScoreRank,
        RANK() OVER (ORDER BY CreationDate DESC) AS RecentRank
    FROM 
        RecentPosts
), PopularTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(ARRAY_AGG(DISTINCT Tags.TagName), ', ')) AS TagName
    FROM 
        Posts p
    JOIN 
        Tags ON POSITION(Tags.TagName IN p.Tags) > 0
    WHERE 
        p.Score > 10
    GROUP BY 
        Tags.TagName
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rt.TagName,
    ur.DisplayName AS UserName,
    ur.Reputation AS UserReputation,
    CASE 
        WHEN ur.Reputation > 1000 THEN 'Experienced'
        WHEN ur.Reputation > 100 THEN 'Novice'
        ELSE 'Beginner'
    END AS UserExperienceLevel
FROM 
    RankPosts rp
LEFT JOIN 
    PopularTags rt ON rt.TagName IS NOT NULL
JOIN 
    Users u ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    rp.Score DESC, rp.RecentRank ASC;
