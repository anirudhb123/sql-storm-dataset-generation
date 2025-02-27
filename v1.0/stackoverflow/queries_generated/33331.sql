WITH RecursivePostScores AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 10 THEN 1 END) AS Deletions,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.UpVotes,
        ps.DownVotes,
        (ps.UpVotes - ps.DownVotes) AS Score,
        (CASE 
            WHEN ps.UpVotes + ps.DownVotes = 0 THEN NULL 
            ELSE CAST(ps.UpVotes AS FLOAT) / (ps.UpVotes + ps.DownVotes) 
        END) AS VoteRatio,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        COALESCE(p.ClosedDate, 'Open') AS PostStatus,
        ps.HistoryCount
    FROM 
        RecursivePostScores ps
    JOIN 
        Posts p ON ps.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    GROUP BY 
        ps.PostId, ps.UpVotes, ps.DownVotes, p.Title, u.DisplayName, u.Reputation, p.ClosedDate, ps.HistoryCount
),
RankedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.OwnerReputation,
        pd.Score,
        pd.VoteRatio,
        pd.TagsList,
        pd.PostStatus,
        RANK() OVER (ORDER BY pd.Score DESC, pd.HistoryCount DESC) AS Rank
    FROM 
        PostDetails pd
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.OwnerReputation,
    rp.Score,
    rp.VoteRatio,
    rp.TagsList,
    rp.PostStatus,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top Post'
        WHEN rp.Score IS NULL THEN 'No Votes'
        ELSE 'Average Post'
    END AS PostCategory
FROM 
    RankedPosts rp
WHERE 
    rp.PostStatus = 'Open' OR rp.Score IS NOT NULL
ORDER BY 
    rp.Rank
LIMIT 50;
