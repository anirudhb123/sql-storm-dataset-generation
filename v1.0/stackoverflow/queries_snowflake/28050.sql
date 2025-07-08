
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
        TRIM(UNNEST(SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS QuestionCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        TRIM(UNNEST(SPLIT(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')))
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
        ph.CreationDate > DATEADD(DAY, -30, '2024-10-01 12:34:56')
),
AggregatedChanges AS (
    SELECT 
        PostId,
        COUNT(*) AS ChangeCount,
        LISTAGG(DISTINCT ChangeType || ': ' || ChangeDescription, '; ') WITHIN GROUP (ORDER BY ChangeType) AS Changes
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
    TopTags tt ON POSITION(tt.TagName IN rp.Tags) > 0
LEFT JOIN 
    AggregatedChanges ag ON rp.PostId = ag.PostId
WHERE 
    rp.Rank = 1
ORDER BY 
    tt.QuestionCount DESC, rp.Score DESC;
