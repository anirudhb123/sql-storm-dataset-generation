WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS TagRanking,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 -- Only questions
        AND p.CreationDate > NOW() - INTERVAL '1 year' -- Only posts from the last year
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        av.UpVotesCount,
        av.DownVotesCount,
        rp.TagName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedVotes av ON rp.PostId = av.PostId
)

SELECT 
    ps.TagName,
    COUNT(*) AS TotalPosts,
    AVG(ps.ViewCount) AS AvgViews,
    AVG(ps.AnswerCount) AS AvgAnswers,
    AVG(ps.CommentCount) AS AvgComments,
    AVG(ps.UpVotesCount) AS AvgUpVotes,
    AVG(ps.DownVotesCount) AS AvgDownVotes
FROM 
    PostStatistics ps
GROUP BY 
    ps.TagName
ORDER BY 
    TotalPosts DESC;
