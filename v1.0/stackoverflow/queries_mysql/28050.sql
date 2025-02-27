
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS Author,
        p.Tags,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagSummary AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '>', -1)) AS TagName,
        COUNT(*) AS QuestionCount
    FROM 
        Posts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        QuestionCount,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS TagRank
    FROM 
        TagSummary
    WHERE 
        QuestionCount > 5
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS EditDate,
        p.Title AS PostTitle,
        p.Score,
        p.Tags,
        PHT.Name AS ChangeType,
        ph.Text AS ChangeDescription
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL 30 DAY
),
AggregatedChanges AS (
    SELECT 
        PostId,
        COUNT(*) AS ChangeCount,
        GROUP_CONCAT(DISTINCT CONCAT(ChangeType, ': ', ChangeDescription) ORDER BY ChangeType SEPARATOR '; ') AS Changes
    FROM 
        RecentPostHistory
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Author,
    rp.CreationDate,
    rp.Tags,
    rp.Score,
    tt.TagName,
    ag.ChangeCount,
    ag.Changes
FROM 
    RankedPosts rp
LEFT JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%') 
LEFT JOIN 
    AggregatedChanges ag ON rp.PostId = ag.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    tt.QuestionCount DESC, rp.Score DESC;
