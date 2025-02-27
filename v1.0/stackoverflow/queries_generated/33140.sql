WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'UpMod') AS UpVotes,
        COUNT(v.Id) FILTER (WHERE vt.Name = 'DownMod') AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate > current_date - interval '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostInteractions AS (
    SELECT 
        p.PostId,
        p.Title,
        p.OwnerName,
        p.CreationDate,
        p.CommentCount,
        p.UpVotes,
        p.DownVotes,
        CASE 
            WHEN p.CommentCount > 10 THEN 'Highly Engaged'
            WHEN p.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Engaged'
            ELSE 'Low Engagement'
        END AS EngagementLevel
    FROM 
        RankedPosts p
    WHERE 
        p.PostRank <= 5
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date > current_date - interval '30 days'
    GROUP BY 
        b.UserId
)
SELECT 
    pi.PostId,
    pi.Title,
    pi.OwnerName,
    pi.CreationDate,
    pi.CommentCount,
    pi.UpVotes,
    pi.DownVotes,
    pi.EngagementLevel,
    rb.BadgeNames
FROM 
    PostInteractions pi
LEFT JOIN 
    RecentBadges rb ON pi.OwnerName = rb.UserId
ORDER BY 
    pi.CreationDate DESC
LIMIT 50;
