WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS RankByScore,
        SUM(v.VoteTypeId = 2) AS UpVotes, 
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        ViewCount, 
        AnswerCount, 
        OwnerDisplayName, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
)
SELECT 
    trp.PostId, 
    trp.Title, 
    trp.Score, 
    trp.ViewCount, 
    trp.AnswerCount, 
    trp.OwnerDisplayName, 
    trp.UpVotes, 
    trp.DownVotes,
    AVG(pht.Class) AS AverageBadgeClass,
    COUNT(c.Id) AS CommentsCount
FROM 
    TopRankedPosts trp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = trp.PostId)
LEFT JOIN 
    Comments c ON c.PostId = trp.PostId
LEFT JOIN 
    PostHistory pht ON pht.PostId = trp.PostId
GROUP BY 
    trp.PostId, trp.Title, trp.Score, trp.ViewCount, trp.AnswerCount, trp.OwnerDisplayName, trp.UpVotes, trp.DownVotes
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
