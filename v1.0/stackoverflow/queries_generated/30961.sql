WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    GROUP BY 
        p.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    WHERE 
        b.Date > CURRENT_DATE - INTERVAL '1 YEAR'  -- Badges awarded in the last year
    GROUP BY 
        b.UserId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        MAX(ph.UserDisplayName) AS LastEditorName
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.OwnerDisplayName,
    rb.BadgeCount,
    rb.HighestBadgeClass,
    ph.LastEditDate,
    ph.LastEditorName,
    COALESCE(rp.CommentCount, 0) AS TotalComments,
    COALESCE(rp.UpVotes, 0) AS TotalUpVotes,
    COALESCE(rp.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN rp.Score >= 10 THEN 'Popular'
        WHEN rp.Score BETWEEN 1 AND 9 THEN 'Average'
        ELSE 'Unpopular'
    END AS Popularity
FROM 
    RankedPosts rp
LEFT JOIN 
    UserBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    PostHistoryStats ph ON rp.Id = ph.PostId
WHERE 
    rp.Rank <= 5  -- Get top 5 posts per user
ORDER BY 
    rp.Score DESC
LIMIT 50;  -- Limit the overall query result to 50 rows
