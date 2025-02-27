WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS PostBody,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t WHERE t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) AS TagList
    FROM 
        Posts p
    WHERE 
        p.CreationDate < NOW() - INTERVAL '1 year'
),
PostCloseReasons AS (
    SELECT 
        ph.PostId,
        MIN(CRT.Name) AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes CRT ON ph.Comment::int = CRT.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostVoteStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FinalPostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostBody,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.TagList,
        COALESCE(pcr.CloseReason, 'Open') AS PostCloseReason,
        pvs.UpVoteCount,
        pvs.DownVoteCount,
        rp.PostRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostCloseReasons pcr ON rp.PostId = pcr.PostId
    LEFT JOIN 
        PostVoteStatistics pvs ON rp.PostId = pvs.PostId
)
SELECT 
    *,
    CASE 
        WHEN UpVoteCount > DownVoteCount THEN 'Positive Feedback'
        WHEN UpVoteCount < DownVoteCount THEN 'Negative Feedback'
        ELSE 'Neutral'
    END AS FeedbackType,
    CASE 
        WHEN PostRank = 1 THEN 'Most Recent Post'
        ELSE 'Older Post'
    END AS PostStatus
FROM 
    FinalPostStats
WHERE 
    PostRank <= 5
ORDER BY 
    Score DESC, CreationDate DESC;
