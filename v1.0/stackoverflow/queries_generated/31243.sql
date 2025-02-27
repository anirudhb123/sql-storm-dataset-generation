WITH RECURSIVE RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.PostTypeId,
        rp.Level + 1
    FROM 
        Posts p
    JOIN 
        RecentPosts rp ON p.ParentId = rp.PostId
    WHERE 
        rp.Level < 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ub.DisplayName AS OwnerDisplayName,
    ub.BadgeCount,
    COALESCE(vs.UpVotes, 0) AS UpVoteCount,
    COALESCE(vs.DownVotes, 0) AS DownVoteCount,
    CASE 
        WHEN rp.PostTypeId = 1 THEN 'Question'
        WHEN rp.PostTypeId = 2 THEN 'Answer'
        ELSE 'Other'
    END AS PostType,
    (SELECT COUNT(c.Id) 
     FROM Comments c 
     WHERE c.PostId = rp.PostId) AS CommentCount,
    (SELECT STRING_AGG(t.TagName, ', ') 
     FROM Tags t 
     WHERE t.WikiPostId IN (SELECT Id FROM Posts WHERE Id = rp.PostId)) AS TagsUsed
FROM 
    RecentPosts rp
LEFT JOIN 
    Users ub ON rp.OwnerUserId = ub.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = rp.OwnerUserId
LEFT JOIN 
    VoteSummary vs ON rp.PostId = vs.PostId
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;
