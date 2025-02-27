WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COUNT(v.Id) OVER (PARTITION BY p.Id) AS VoteCount,
        COALESCE((
            SELECT 
                COUNT(b.Id)
            FROM 
                Badges b
            WHERE 
                b.UserId = p.OwnerUserId AND b.Class = 1
        ), 0) AS GoldBadgeCount,
        COALESCE((
            SELECT 
                COUNT(DISTINCT Tags)
            FROM 
                (SELECT unnest(string_to_array(p.Tags, '>')) AS Tags) AS TagList
        ), 0) AS UniqueTagCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 3 -- Downvotes only
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedPostStats AS (
    SELECT
        PostId,
        COUNT(DISTINCT CommentCount) AS TotalComments,
        SUM(CASE WHEN RankScore = 1 THEN 1 ELSE 0 END) AS TopAnswerCount,
        AVG(ViewCount) AS AvgViewCount,
        MAX(GoldBadgeCount) AS MaxGoldBadges,
        SUM(UniqueTagCount) AS totalUniqueTags
    FROM 
        RankedPosts
    GROUP BY 
        PostId
),
FinalReport AS (
    SELECT 
        ap.PostId,
        p.Title,
        p.CreationDate,
        aps.TotalComments,
        aps.TopAnswerCount,
        aps.AvgViewCount,
        aps.MaxGoldBadges,
        aps.totalUniqueTags,
        CASE 
            WHEN aps.AvgViewCount > 100 THEN 'Popular'
            WHEN aps.AvgViewCount BETWEEN 50 AND 100 THEN 'Moderate'
            ELSE 'Unpopular'
        END AS Popularity
    FROM 
        AggregatedPostStats aps
    JOIN 
        Posts p ON p.Id = aps.PostId
    WHERE 
        p.ClosedDate IS NULL
)
SELECT 
    f.*,
    pt.Name AS PostType,
    GROUP_CONCAT(DISTINCT COALESCE(t.TagName, 'No Tags') ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    FinalReport f
LEFT JOIN 
    PostTypes pt ON pt.Id = (SELECT PostTypeId FROM Posts WHERE Id = f.PostId)
LEFT JOIN 
    Tags t ON t.WikiPostId = f.PostId
GROUP BY 
    f.PostId
HAVING 
    f.TotalComments > 0
ORDER BY 
    f.AvgViewCount DESC;
