WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Summary,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName,
        CommentCount,
        TotalUpVotes,
        TotalDownVotes,
        RANK() OVER (ORDER BY Score DESC, ViewCount DESC) AS PostRank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    p.*,
    CASE 
        WHEN TotalUpVotes > TotalDownVotes THEN 'Positive' 
        WHEN TotalUpVotes < TotalDownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    TopPosts p
WHERE 
    PostRank <= 10
ORDER BY 
    Score DESC, ViewCount DESC;
