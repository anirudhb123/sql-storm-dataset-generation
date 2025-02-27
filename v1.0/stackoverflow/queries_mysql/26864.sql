
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType,
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagList,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.PostTypeId, p.Tags, p.AcceptedAnswerId
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name) AS HistoryTypes,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostType,
    rp.CreationDate,
    rp.TagList,
    pha.HistoryTypes,
    pha.EditCount,
    pha.LastEditDate,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    (rp.UpVoteCount - rp.DownVoteCount) AS NetScore,
    CASE 
        WHEN rp.AcceptedAnswer > 0 THEN 'Accepted Answer Exists'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryAggregated pha ON rp.PostId = pha.PostId
ORDER BY 
    NetScore DESC,
    rp.CreationDate DESC
LIMIT 50;
