WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE
            WHEN rp.Rank <= 5 THEN 'Top 5'
            WHEN rp.Rank <= 20 THEN 'Top 20'
            ELSE 'Other'
        END AS RankGroup
    FROM 
        RankedPosts rp
)
SELECT 
    pd.RankGroup,
    COUNT(pd.PostId) AS PostCount,
    AVG(pd.Score) AS AvgScore,
    AVG(pd.ViewCount) AS AvgViewCount,
    AVG(pd.CommentCount) AS AvgCommentCount,
    SUM(pd.UpVoteCount) AS TotalUpVotes,
    SUM(pd.DownVoteCount) AS TotalDownVotes
FROM 
    PostDetails pd
GROUP BY 
    pd.RankGroup
ORDER BY 
    FIELD(pd.RankGroup, 'Top 5', 'Top 20', 'Other');
