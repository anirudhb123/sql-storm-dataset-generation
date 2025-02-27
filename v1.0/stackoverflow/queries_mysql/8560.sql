
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        @row_num := IF(@current_user_id = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @current_user_id := p.OwnerUserId
    FROM 
        Posts p,
        (SELECT @row_num := 0, @current_user_id := NULL) AS vars
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC, p.CreationDate DESC
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
             (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
              UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
             (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
              UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) numbers 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.DisplayName,
    us.TotalQuestions,
    us.TotalScore,
    us.TotalViews,
    pt.TagName
FROM 
    RankedPosts rp
JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
JOIN 
    PostLinks pl ON rp.PostId = pl.PostId
JOIN 
    PopularTags pt ON pl.RelatedPostId IN (SELECT Id FROM Posts WHERE FIND_IN_SET(pt.TagName, Tags))
WHERE 
    rp.Rank = 1 
ORDER BY 
    us.TotalScore DESC, rp.Score DESC;
