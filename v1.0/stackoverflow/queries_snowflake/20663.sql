
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 YEAR' 
        AND p.ViewCount IS NOT NULL
),
RecentVotes AS (
    SELECT 
        v.PostId,
        v.VoteTypeId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 DAYS'
    GROUP BY 
        v.PostId, v.VoteTypeId
),
PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount,
        CASE 
            WHEN rv.VoteTypeId = 2 THEN 'Upvote'
            WHEN rv.VoteTypeId = 3 THEN 'Downvote'
            ELSE 'No recent votes'
        END AS VoteType
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.Rank <= 10
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        LISTAGG(CONCAT(pht.Name, ': ', ph.Comment), '; ') WITHIN GROUP (ORDER BY ph.PostId) AS HistoryComments
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '6 MONTHS'
    GROUP BY 
        ph.PostId
)
SELECT 
    pw.PostId,
    pw.Title,
    pw.ViewCount,
    pw.RecentVoteCount,
    pw.VoteType,
    COALESCE(phd.HistoryComments, 'No history comments') AS PostHistory
FROM 
    PostWithVotes pw
LEFT JOIN 
    PostHistoryDetail phd ON pw.PostId = phd.PostId
WHERE 
    pw.RecentVoteCount > 0
    OR pw.VoteType != 'No recent votes'
ORDER BY 
    pw.ViewCount DESC, pw.Title
LIMIT 100;
