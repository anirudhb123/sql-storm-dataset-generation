WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        COALESCE(CAST(p.Body AS VARCHAR(200)), 'No body text available') AS BodySnippet,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        PostsTags ptg ON p.Id = ptg.PostId
    LEFT JOIN 
        Tags t ON ptg.TagId = t.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
        AND t.IsModeratorOnly = 0
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.ViewCount, p.Score
),
PostWithMostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostsWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        rp.BodySnippet,
        rp.Tags,
        COALESCE(pwc.CommentCount, 0) AS TotalComments,
        COALESCE(pb.BadgeCount, 0) AS TotalBadges
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostWithMostComments pwc ON rp.PostId = pwc.PostId
    LEFT JOIN 
        PostsWithBadges pb ON rp.PostId = pb.UserId
    WHERE 
        rp.RankScore <= 5  -- Top 5 posts per type
)
SELECT 
    Fr.PostId,
    Fr.Title,
    Fr.CreationDate,
    Fr.ViewCount,
    Fr.Score,
    Fr.TotalComments,
    Fr.TotalBadges,
    CASE 
        WHEN Fr.TotalBadges > 0 THEN 'Has Badges'
        ELSE 'No Badges'
    END AS BadgeAvailability,
    CASE 
        WHEN Fr.Score IS NULL THEN 'Score not available'
        WHEN Fr.Score >= 0 THEN 'Positive Score'
        ELSE 'Negative Score'
    END AS ScoreStatus
FROM 
    FinalResults Fr
ORDER BY 
    Fr.CreationDate DESC;
