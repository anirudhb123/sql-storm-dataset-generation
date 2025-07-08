
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.LastActivityDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
),
PostScoreStats AS (
    SELECT 
        pr.OwnerUserId,
        COUNT(DISTINCT pr.PostId) AS TotalQuestions,
        AVG(pr.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN pr.Rank = 1 THEN 1 ELSE 0 END) AS AcceptedAnswersCount  
    FROM 
        RankedPosts pr
    GROUP BY 
        pr.OwnerUserId
),
PopularTags AS (
    SELECT 
        TRIM(SPLIT_PART(tag, '><', i)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(input => SPLIT(p.Tags, '><')) AS f
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ps.TotalQuestions,
    ps.AvgViewCount,
    ps.AcceptedAnswersCount,
    LISTAGG(DISTINCT pt.TagName, ', ') AS PopularTags
FROM 
    Users u
LEFT JOIN 
    PostScoreStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT TRIM(SPLIT_PART(tag, '><', i))
        FROM Posts p,
        LATERAL FLATTEN(input => SPLIT(p.Tags, '><')) AS f
        WHERE p.OwnerUserId = u.Id
        AND p.PostTypeId = 1
    )
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ps.TotalQuestions, ps.AvgViewCount, ps.AcceptedAnswersCount
ORDER BY 
    ps.TotalQuestions DESC,
    u.Reputation DESC
LIMIT 20;
