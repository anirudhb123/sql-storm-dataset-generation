
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
        value AS TagName,
        COUNT(*) AS TagFrequency
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
)
SELECT 
    tc.UserId,
    tc.DisplayName,
    tc.TotalScore,
    tc.QuestionCount,
    tc.PositiveResponses,
    COUNT(rp.PostId) AS RecentPostsCount,
    STRING_AGG(ft.TagName, ', ') AS MostFrequentTags
FROM 
    TopContributors tc
LEFT JOIN 
    RankedPosts rp ON tc.UserId = rp.OwnerUserId AND rp.UserPostRank <= 5
LEFT JOIN 
    FrequentTags ft ON ft.TagName IN (
        SELECT TOP 5 
            TagName
        FROM 
            FrequentTags
        ORDER BY 
            TagFrequency DESC
    )
GROUP BY 
    tc.UserId, tc.DisplayName, tc.TotalScore, tc.QuestionCount, tc.PositiveResponses
ORDER BY 
    tc.TotalScore DESC;
