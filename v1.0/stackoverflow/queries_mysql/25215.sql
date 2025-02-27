
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= CURRENT_DATE - INTERVAL 1 YEAR
),
TagCounts AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', -1), '<', 1) AS Tag, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '>', -1), '<', 1)
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE
        PostCount > 5 
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate,
        GROUP_CONCAT(pt.Name SEPARATOR ', ') AS EditHistory
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Body,
        r.CreationDate,
        r.OwnerUserId,
        r.OwnerDisplayName,
        r.Tags,
        e.EditCount,
        e.LastEditedDate,
        t.PostCount AS TagPostCount,
        t.Tag AS TopTag
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostHistories e ON r.PostId = e.PostId
    JOIN 
        TopTags t ON t.Tag = SUBSTRING_INDEX(SUBSTRING_INDEX(r.Tags, '>', -1), '<', 1)
    WHERE 
        r.Rank <= 5 
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    TagPostCount DESC, 
    CreationDate DESC;
