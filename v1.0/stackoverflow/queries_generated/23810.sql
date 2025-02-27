WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.PostTypeId
),
PostVoteCounts AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON vt.Id = v.VoteTypeId
    GROUP BY 
        v.PostId
),
ClosedPosts AS (
    SELECT DISTINCT 
        ph.PostId
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)   -- 10 = Post Closed, 11 = Post Reopened
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    COALESCE(pvc.UpVotes, 0) AS UpVotes,
    COALESCE(pvc.DownVotes, 0) AS DownVotes,
    COALESCE(pvc.TotalVotes, 0) AS TotalVotes,
    rp.Rank,
    rp.Tags,
    CASE 
        WHEN cp.PostId IS NOT NULL THEN 'Closed'
        ELSE 'Active' 
    END AS PostStatus,
    us.UserId,
    us.DisplayName,
    us.BadgeCount,
    us.MaxReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pvc ON pvc.PostId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON cp.PostId = rp.PostId
JOIN 
    Users u ON u.Id = rp.OwnerUserId
LEFT JOIN 
    UserStatistics us ON us.UserId = u.Id
WHERE 
    rp.Rank <= 10   -- Top 10 posts in each type based on score
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
