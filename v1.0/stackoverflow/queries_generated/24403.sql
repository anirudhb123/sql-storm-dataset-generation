WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        U.Reputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' AND
        p.AnswerCount > 0 -- Only consider questions with answers
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(CAST(p2.Tags AS text[]), '{}') AS Tags,
        COALESCE(p2.Body, '') AS Body,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p2 ON rp.PostId = p2.Id
    LEFT JOIN 
        Comments c ON p2.Id = c.PostId
    LEFT JOIN 
        Votes v ON p2.Id = v.PostId
    WHERE 
        rp.ViewRank <= 10 -- Get top 10 posts by view count per type
    GROUP BY 
        rp.PostId, rp.Title, rp.ViewCount
),
HistoricalRecords AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.Tags,
        pd.Body,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        hr.ClosedDate,
        hr.ReopenedDate,
        hr.HistoryCount,
        CASE 
            WHEN hr.ClosedDate IS NOT NULL AND hr.ReopenedDate IS NULL THEN 'Closed'
            WHEN hr.ReopenedDate IS NOT NULL THEN 'Reopened'
            ELSE 'Active'
        END AS PostStatus
    FROM 
        PostDetails pd
    LEFT JOIN 
        HistoricalRecords hr ON pd.PostId = hr.PostId
)
SELECT 
    *,
    CASE 
        WHEN Body IS NULL OR Body = '' THEN 'No Content'
        ELSE 'Content Available'
    END AS ContentAvailability,
    ARRAY_AGG(DISTINCT UNNEST(Tags)) AS DistinctTags
FROM 
    FinalResults
GROUP BY 
    PostId, Title, ViewCount, Tags, Body, CommentCount, UpVotes, DownVotes, ClosedDate, ReopenedDate, HistoryCount, PostStatus
ORDER BY 
    ViewCount DESC;
