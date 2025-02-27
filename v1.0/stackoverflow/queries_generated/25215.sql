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
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts from the last year
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags) - 2), '><')) AS Tag, 
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Questions only
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagCounts
    WHERE
        PostCount > 5 -- Only tags with more than 5 questions
),
PostHistories AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(pt.Name, ', ') AS EditHistory
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
        TopTags t ON t.Tag = ANY (string_to_array(substring(r.Tags, 2, length(r.Tags) - 2), '><'))
    WHERE 
        r.Rank <= 5 -- Top 5 viewed questions per tag
)
SELECT 
    *
FROM 
    FinalResults
ORDER BY 
    TagPostCount DESC, 
    CreationDate DESC;
