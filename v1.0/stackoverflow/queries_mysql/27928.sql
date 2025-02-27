
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.Body, 
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId IN (2, 6) THEN 1 ELSE 0 END) AS UpVotes,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @rownum := @rownum + 1 AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rownum := 0) r
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        *,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts
    WHERE 
        ViewCount > 100  
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CreationDate,
        ViewCount, 
        CommentCount, 
        NetVotes,
        @rank := IF(@prevNetVotes = NetVotes, @rank, @rank + 1) AS VoteRank,
        @prevNetVotes := NetVotes
    FROM 
        FilteredPosts
    CROSS JOIN (SELECT @rank := 0, @prevNetVotes := NULL) r
    ORDER BY NetVotes DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.NetVotes,
    CASE 
        WHEN tp.VoteRank <= 10 THEN 'Top Trending'
        WHEN tp.VoteRank BETWEEN 11 AND 50 THEN 'Popular'
        ELSE 'Less Active'
    END AS PostCategory
FROM 
    TopPosts tp
WHERE 
    tp.VoteRank <= 50  
ORDER BY 
    tp.VoteRank;
