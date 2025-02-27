WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.Score > 10 THEN 'High'
            WHEN rp.Score BETWEEN 1 AND 10 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
    AND 
        rp.UpVotes - rp.DownVotes > 0
),
UserAggregates AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT bp.PostId) AS PostCount,
        SUM(bp.CommentCount) AS TotalComments,
        AVG(bp.ViewCount) AS AvgViewCount,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        FilteredPosts bp ON u.Id = bp.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    ua.UserId,
    ua.PostCount,
    ua.TotalComments,
    ua.AvgViewCount,
    CASE 
        WHEN ua.PostCount > 10 THEN 'Active'
        WHEN ua.PostCount BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityLevel,
    COALESCE(ua.BadgeNames, 'No Badges') AS BadgesAwarded
FROM 
    UserAggregates ua
WHERE 
    ua.PostCount > 0
ORDER BY 
    ua.PostCount DESC,
    ua.TotalComments DESC;

