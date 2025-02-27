
WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        u.DisplayName as OwnerName,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) as AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) as PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
AggregatedData AS (
    SELECT 
        rp.OwnerName,
        COUNT(rp.PostId) as QuestionCount,
        SUM(CASE WHEN rp.AcceptedAnswerId > 0 THEN 1 ELSE 0 END) as AcceptedCount,
        AVG(u.Reputation) as AverageReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerName = u.DisplayName
    GROUP BY 
        rp.OwnerName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) as CloseVotes
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ', ', numbers.n), ', ', -1) as TagName
    FROM 
        Posts p
    INNER JOIN 
        (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ', ', '')) >= numbers.n - 1
    WHERE 
        p.PostTypeId = 1
),
TagCounts AS (
    SELECT 
        TagName,
        COUNT(*) as TagUsage
    FROM 
        PopularTags
    GROUP BY 
        TagName
    ORDER BY 
        TagUsage DESC
)
SELECT 
    ad.OwnerName,
    ad.QuestionCount,
    ad.AcceptedCount,
    ad.AverageReputation,
    COALESCE(cp.CloseVotes, 0) as CloseVotes,
    tc.TagName,
    tc.TagUsage
FROM 
    AggregatedData ad
LEFT JOIN 
    ClosedPosts cp ON ad.OwnerName = (
        SELECT 
            u.DisplayName 
        FROM 
            Users u 
        WHERE 
            u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.PostId)
        LIMIT 1
    )
JOIN 
    TagCounts tc ON ad.QuestionCount = (SELECT MAX(QuestionCount) FROM AggregatedData)
WHERE 
    ad.AverageReputation IS NOT NULL
ORDER BY 
    ad.QuestionCount DESC, ad.AverageReputation DESC
LIMIT 10;
