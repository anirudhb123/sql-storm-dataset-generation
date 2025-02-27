WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.AcceptedAnswerId, 
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
PostVoteCounts AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes, 
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes 
    FROM 
        Votes 
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.Score,
        rp.OwnerDisplayName,
        COALESCE(pvc.UpVotes, 0) AS UpVotes,
        COALESCE(pvc.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteCounts pvc ON rp.PostId = pvc.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.PostId, 
    pd.Title, 
    pd.CreationDate, 
    pd.Score, 
    pd.UpVotes, 
    pd.DownVotes,
    CASE 
        WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive'
        WHEN pd.UpVotes - pd.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT STRING_AGG(CONCAT(t.TagName, ' '), ', ') 
     FROM Tags t 
     WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(Tags)-2), '><')::int[])::int[]) 
                FROM Posts p WHERE p.Id = pd.PostId)) AS TagsList
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC
FETCH FIRST 10 ROWS ONLY;
