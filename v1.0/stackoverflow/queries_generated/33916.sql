WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) as CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as Rank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        CommentCount,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10 -- Top 10 posts per post type
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) as BadgeCount
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    up.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    ub.BadgeCount,
    CASE 
        WHEN tp.Score > 100 THEN 'High'
        WHEN tp.Score BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS ScoreCategory,
    COALESCE(NULLIF(up.Location, ''), 'Location Not Provided') AS UserLocation,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    TopPosts tp
JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    Users up ON p.OwnerUserId = up.Id
LEFT JOIN 
    UserBadges ub ON ub.UserId = up.Id
LEFT JOIN 
    LATERAL (
        SELECT 
            STRING_AGG(tag.TagName, ', ') AS TagName
        FROM 
            Tags tag
        WHERE 
            tag.Id IN (SELECT UNNEST(string_to_array(p.Tags, ','))::int)
    ) t ON true
GROUP BY 
    up.DisplayName, tp.Title, tp.CreationDate, tp.Score, tp.CommentCount, ub.BadgeCount
ORDER BY 
    tp.Score DESC;
