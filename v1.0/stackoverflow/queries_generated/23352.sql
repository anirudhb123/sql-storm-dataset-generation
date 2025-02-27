WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > (NOW() - INTERVAL '1 year')
        AND p.Score IS NOT NULL
),

PostMetrics AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoterCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        SUM(voteAdjustment) AS NetVotes 
    FROM 
        RankedPosts r
    LEFT JOIN 
        Comments c ON r.PostId = c.PostId
    LEFT JOIN 
        Votes v ON r.PostId = v.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE 
                WHEN v.VoteTypeId = 1 THEN 1 
                WHEN v.VoteTypeId = 10 THEN -1 
                ELSE 0 
            END) AS voteAdjustment
        FROM 
            Votes v
        GROUP BY 
            PostId
    ) AS vote_summary ON r.PostId = vote_summary.PostId
    GROUP BY 
        PostId
),

PostHistoryMetrics AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS PostHistoryComments,
        ARRAY_AGG(DISTINCT pht.Name) AS PostHistoryActions
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= (NOW() - INTERVAL '6 months') 
    GROUP BY 
        ph.PostId
),

FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pm.CommentCount,
        pm.UniqueVoterCount,
        pm.UpVotes,
        pm.DownVotes,
        COALESCE(phm.PostHistoryComments, 'No comments') AS PostHistoryComments,
        COALESCE(phm.PostHistoryActions, ARRAY[NULL]::varchar[]) AS PostHistoryActions
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostMetrics pm ON rp.PostId = pm.PostId
    LEFT JOIN 
        PostHistoryMetrics phm ON rp.PostId = phm.PostId
    WHERE 
        rp.RankScore <= 5
)

SELECT 
    *,
    CASE 
        WHEN UpVotes > DownVotes THEN 'Positive'
        WHEN UpVotes < DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    LEAST(UPPER(Title), 'Limit Title Length') AS ShortTitle
FROM 
    FinalResults
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 10;
