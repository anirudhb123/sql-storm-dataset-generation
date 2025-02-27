WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank,
        COALESCE(NULLIF(LENGTH(p.Body), 0), 1) AS BodyLength
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- We're only interested in questions
        p.CreationDate BETWEEN NOW() - INTERVAL '1 year' AND NOW()
),
UserInfo AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        u.DisplayName,
        rp.Score,
        u.QuestionCount,
        u.GoldBadges,
        u.AverageBounty,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId IN (
            SELECT 
                p.Id 
            FROM 
                Posts p 
            WHERE 
                p.OwnerUserId = u.Id
        )
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId AND v.VoteTypeId = 2 -- Upvote
    WHERE 
        rp.Rank <= 5 -- Get top 5 posts per user
    GROUP BY 
        rp.PostId, rp.Title, u.DisplayName, rp.Score, u.QuestionCount, u.GoldBadges, u.AverageBounty
)
SELECT 
    pp.PostId, 
    pp.Title,
    pp.DisplayName,
    pp.Score,
    pp.QuestionCount,
    pp.GoldBadges,
    pp.AverageBounty,
    pp.VoteCount,
    CASE 
        WHEN pp.Score > 50 THEN 'Highly Rated'
        WHEN pp.Score BETWEEN 20 AND 50 THEN 'Moderately Rated'
        ELSE 'Low Rated'
    END AS RatingCategory,
    (SELECT 
        COUNT(*) 
     FROM 
        Comments c 
     WHERE 
        c.PostId = pp.PostId
    ) AS CommentCount
FROM 
    PopularPosts pp
WHERE 
    pp.BountyAmount IS NULL OR pp.BountyAmount = 0
ORDER BY 
    pp.Score DESC
LIMIT 50;

This SQL query performs several intricate operations over the StackOverflow schema, incorporating multiple constructs such as Common Table Expressions (CTEs), window functions, aggregation, and subqueries. The query first ranks questions to find the top-scoring questions by user over the last year. It then aggregates user data to include information about badges, average bounty, and question counts. Popular posts are ranked and filtered, leading to a final selection of key details about top posts with their corresponding user data. The incorporation of rating categories and comment counts adds further detail to the final output, enhancing the query's complexity and usefulness for performance benchmarking.
