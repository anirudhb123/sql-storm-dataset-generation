WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        UpVoteCount
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 3 -- Keep top 3 posts per user based on Score
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        MAX(ph.CreationDate) AS LastHistoryDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, ',')) AS Tag(TagName) ON TRUE
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerDisplayName,
        p.CommentCount,
        p.UpVoteCount,
        pt.Tags,
        CASE 
            WHEN pt.LastHistoryDate IS NOT NULL AND p.CreationDate < pt.LastHistoryDate THEN 'Edited'
            ELSE 'New'
        END AS PostTypeStatus
    FROM 
        FilteredPosts p
    LEFT JOIN 
        PostHistoryWithTags pt ON p.PostId = pt.PostId
)

SELECT 
    fr.*,
    CASE 
        WHEN fr.Score IS NULL THEN 'No Score'
        WHEN fr.Score > 0 THEN 'Positive Score'
        ELSE 'Negative Score'
    END AS ScoreStatus,
    COALESCE(fr.CommentCount, 0) AS ActualCommentCount,
    fr.Tags IS NULL AS HasNoTags
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC
LIMIT 100;
