WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only Questions
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(ph.Comment, '; ') AS EditComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
    GROUP BY 
        ph.PostId, ph.CreationDate
),
HighScoringTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(p.Tags, ', '))
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5 AND SUM(p.ViewCount) > 1000
),
TopQuestions AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        re.EditComments
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits re ON rp.Id = re.PostId
    WHERE 
        rp.rank <= 10 -- Top 10 Questions
)
SELECT 
    tq.Title AS QuestionTitle,
    tq.OwnerDisplayName AS AskedBy,
    tq.CreationDate AS DateAsked,
    tq.ViewCount AS ViewCount,
    tq.Score AS Score,
    ht.TagName AS RelevantTag,
    ht.PostCount AS NumberOfPostsWithTag,
    ht.TotalViews AS TotalViewsForTag
FROM 
    TopQuestions tq
JOIN 
    HighScoringTags ht ON tq.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE PostTypeId = 1)
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
