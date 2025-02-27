WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        REPLACE(REPLACE(p.Tags, '<', ''), '>', '') AS CleanedTags,
        pt.Name AS PostType,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        RANK() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RankByDate
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, pt.Name
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CleanedTags,
        PostType,
        AnswerCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY UpVotes - DownVotes DESC) AS PopularityRank
    FROM 
        RankedPosts
    WHERE 
        RankByDate = 1
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CleanedTags,
    tp.PostType,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.PopularityRank,
    CASE 
        WHEN tp.PopularityRank <= 10 THEN 'Hot Post'
        WHEN tp.PopularityRank <= 50 THEN 'Trending Post'
        ELSE 'Regular Post'
    END AS PostStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.PopularityRank
LIMIT 100;
