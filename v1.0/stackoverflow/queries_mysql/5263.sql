
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        @row_num := IF(@prev_owner_user_id = p.OwnerUserId, @row_num + 1, 1) AS RankByViews,
        @prev_owner_user_id := p.OwnerUserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN (SELECT @row_num := 0, @prev_owner_user_id := NULL) AS vars ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, u.DisplayName, p.OwnerUserId
),
PopularPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        @popularity_rank := @popularity_rank + 1 AS PopularityRank
    FROM 
        RankedPosts,
        (SELECT @popularity_rank := 0) AS vars
    WHERE 
        RankByViews <= 5
)
SELECT 
    pp.PostId,
    pp.Title,
    pp.ViewCount,
    pp.CreationDate,
    pp.OwnerDisplayName,
    pp.CommentCount,
    pp.UpVotes,
    pp.DownVotes,
    CASE 
        WHEN pp.UpVotes > pp.DownVotes THEN 'Positive'
        WHEN pp.UpVotes < pp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    PopularPosts pp
ORDER BY 
    pp.PopularityRank;
