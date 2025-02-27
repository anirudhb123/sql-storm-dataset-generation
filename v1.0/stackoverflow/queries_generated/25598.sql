WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
TagStatistics AS (
    SELECT 
        UNNEST(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only Questions
    GROUP BY 
        TagName
),
PopularTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 1 -- Tags that appear in more than one question
),
PostHistoryChanges AS (
    SELECT 
        ph.PostId,
        p.Title AS PostTitle,
        ph.CreationDate AS ChangeDate,
        p.OwnerDisplayName,
        p.Body,
        pH.Comments,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Edited'
        END AS ChangeType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 10, 11)  -- Editing title, body, and closure actions
),
RecentHighScorers AS (
    SELECT 
        PostId,
        Score,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Score DESC) AS HighScoreRank
    FROM 
        Posts
    WHERE 
        Score > 10 -- Posts with significant scores
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    pt.TagName,
    ph.ChangeDate,
    ph.ChangeType,
    rhs.Score AS HighScore,
    rhs.CreationDate AS HighScoreDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><'))
LEFT JOIN 
    PostHistoryChanges ph ON rp.PostId = ph.PostId
LEFT JOIN 
    RecentHighScorers rhs ON rp.PostId = rhs.PostId
WHERE 
    rp.PostRank = 1 -- Gets the latest posts by each user
ORDER BY 
    rp.CreationDate DESC, rp.ViewCount DESC, rp.Score DESC;
