WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.ViewCount,
        p.Score,
        COALESCE(a.Body, 'No answers yet') AS AcceptedAnswerBody,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '> <'))::int)
                        WHERE t.TagName IS NOT NULL)
    GROUP BY 
        p.Id, a.Body, u.DisplayName
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS RevisionCount,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostPerformance AS (
    SELECT 
        pm.*,
        psh.RevisionCount,
        psh.LastEditedDate
    FROM 
        PostMetrics pm
    LEFT JOIN 
        PostHistorySummary psh ON pm.PostId = psh.PostId AND psh.PostHistoryTypeId IN (1, 4, 5)
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.TagList,
    pp.ViewCount,
    pp.Score,
    pp.AcceptedAnswerBody,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    pp.RevisionCount,
    pp.LastEditedDate,
    CASE 
        WHEN pp.RevisionCount > 5 THEN 'Highly Edited'
        WHEN pp.RevisionCount BETWEEN 3 AND 5 THEN 'Moderately Edited'
        ELSE 'Rarely Edited'
    END AS EditFrequency,
    CASE 
        WHEN pp.ViewCount > 1000 THEN 'Popular'
        WHEN pp.ViewCount > 500 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS Popularity
FROM 
    PostPerformance pp
WHERE 
    pp.Score > 10
ORDER BY 
    pp.Score DESC, 
    pp.ViewCount DESC;
