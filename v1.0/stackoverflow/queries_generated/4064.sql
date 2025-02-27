WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.ViewCount > 100
    GROUP BY 
        p.Id
),
RecentPostHistories AS (
    SELECT
        ph.PostId,
        STRING_AGG(DISTINCT CONCAT_WS(' - ', ph.UserDisplayName, ph.Text), '; ') AS HistoryComments,
        MAX(ph.CreationDate) AS LastEditedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 6, 24) -- Edit Title, Edit Tags, Suggested Edit Applied
    GROUP BY 
        ph.PostId
),
FinalResult AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rph.HistoryComments,
        rph.LastEditedDate,
        CASE 
            WHEN rp.CommentCount > 5 THEN 'Active'
            ELSE 'Less Active'
        END AS PostActivity
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentPostHistories rph ON rp.PostId = rph.PostId
)

SELECT 
    *,
    (UpVotes - DownVotes) AS NetScore,
    CASE 
        WHEN LastEditedDate IS NOT NULL THEN 
            DATEDIFF('day', LastEditedDate, CURRENT_TIMESTAMP) || ' days ago'
        ELSE 
            'Never Edited'
    END AS LastEditedAgo,
    COALESCE(HistoryComments, 'No history available') AS Comments
FROM 
    FinalResult
WHERE 
    PostRank <= 5
ORDER BY 
    CreationDate DESC;
