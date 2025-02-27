
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        DENSE_RANK() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY p.CreationDate DESC) AS YearRank,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, p.OwnerUserId
),

PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS Frequency
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        Frequency DESC
    LIMIT 10
),

UserReputationChanges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 3 WHEN B.Class = 2 THEN 2 WHEN B.Class = 3 THEN 1 ELSE 0 END) AS TotalGoldSilverBronze
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(CASE WHEN B.Class IS NOT NULL THEN 1 ELSE 0 END) > 0
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.CommentCount,
    rp.AnswerCount,
    rt.TagName,
    urc.DisplayName AS TopUser,
    urc.TotalGoldSilverBronze
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags rt ON rp.Tags LIKE CONCAT('%', rt.TagName, '%')
LEFT JOIN 
    UserReputationChanges urc ON rp.OwnerUserId = urc.UserId
WHERE 
    rp.YearRank <= 5 
ORDER BY 
    rp.CreationDate DESC, urc.TotalGoldSilverBronze DESC;
