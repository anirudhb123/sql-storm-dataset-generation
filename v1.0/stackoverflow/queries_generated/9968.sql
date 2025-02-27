WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Selecting only questions
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.UserPostRank = 1 AND u.Id = rp.OwnerUserId
)
SELECT 
    pd.Title,
    pd.OwnerDisplayName,
    pd.OwnerReputation,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    COALESCE(ph.RecentEditdate, pd.CreationDate) AS LastActivityDate
FROM 
    PostDetails pd
LEFT JOIN 
    Posts p ON pd.PostId = p.Id
LEFT JOIN 
    (SELECT 
         PostId, 
         MAX(LastEditDate) AS RecentEditdate 
     FROM 
         Posts 
     GROUP BY 
         PostId) ph ON p.Id = ph.PostId
ORDER BY 
    pd.Score DESC, 
    pd.ViewCount DESC
LIMIT 10;
