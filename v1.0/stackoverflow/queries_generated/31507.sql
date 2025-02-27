WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only consider Questions
),
RecentActivity AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS HistoryDate, 
        p.Title AS PostTitle,
        ph.UserId,
        U.DisplayName AS UserName,
        ph.Comment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        Users U ON ph.UserId = U.Id
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '30 days'
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS t(TagName)
    GROUP BY p.Id
),
CombinedData AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        ra.HistoryDate,
        ra.UserName,
        ra.Comment,
        pt.Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.Id = ra.PostId
    LEFT JOIN 
        PostTags pt ON rp.Id = pt.PostId
    WHERE 
        rp.PostRank <= 10 -- Top 10 posts by score
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.ViewCount,
    cd.AnswerCount,
    COALESCE(cd.UserName, 'N/A') AS LastEditor,
    COALESCE(cd.HistoryDate::DATE, 'Never') AS LastActivityDate,
    COALESCE(cd.Comment, 'No comments') AS EditComment,
    COALESCE(cd.Tags, 'No tags assigned') AS Tags
FROM 
    CombinedData cd
ORDER BY 
    cd.Score DESC, cd.CreationDate DESC;
