
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        p.OwnerUserId,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score, p.OwnerUserId, p.CreationDate
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveResponses
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),
FrequentTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    INNER JOIN 
    (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
)
SELECT 
    tc.UserId,
    tc.DisplayName,
    tc.TotalScore,
    tc.QuestionCount,
    tc.PositiveResponses,
    COUNT(rp.PostId) AS RecentPostsCount,
    GROUP_CONCAT(ft.TagName ORDER BY ft.TagFrequency DESC) AS MostFrequentTags
FROM 
    TopContributors tc
LEFT JOIN 
    RankedPosts rp ON tc.UserId = rp.OwnerUserId AND rp.UserPostRank <= 5
LEFT JOIN 
    FrequentTags ft ON ft.TagName IN (
        SELECT 
            TagName
        FROM 
            FrequentTags
        ORDER BY 
            TagFrequency DESC
        LIMIT 5
    )
GROUP BY 
    tc.UserId, tc.DisplayName, tc.TotalScore, tc.QuestionCount, tc.PositiveResponses
ORDER BY 
    tc.TotalScore DESC;
