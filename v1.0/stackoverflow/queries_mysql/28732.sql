
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
        AND p.LastActivityDate >= NOW() - INTERVAL 1 YEAR  
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
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT @rownum:=@rownum+1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) t, (SELECT @rownum:=0) r) n 
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
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
    GROUP_CONCAT(DISTINCT pt.TagName ORDER BY pt.TagName ASC SEPARATOR ', ') AS PopularTags
FROM 
    Users u
LEFT JOIN 
    PostScoreStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1))
        FROM Posts p
        JOIN 
            (SELECT @rownum:=@rownum+1 AS n FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) t, (SELECT @rownum:=0) r) n 
        WHERE p.OwnerUserId = u.Id
        AND p.PostTypeId = 1
    )
GROUP BY 
    u.Id, u.DisplayName, u.Reputation, ps.TotalQuestions, ps.AvgViewCount, ps.AcceptedAnswersCount
ORDER BY 
    ps.TotalQuestions DESC,
    u.Reputation DESC
LIMIT 20;
