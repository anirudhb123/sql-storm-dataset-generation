WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        COUNT(DISTINCT ans.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY SUM(v.VoteTypeId = 2) DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts ans ON p.Id = ans.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Filter for Questions
    GROUP BY 
        p.Id, p.Title, p.Tags
), TagMetrics AS (
    SELECT 
        Tags, 
        AVG(AnswerCount) AS AvgAnswers,
        AVG(CommentCount) AS AvgComments,
        SUM(UpVotes) AS TotalUpVotes, 
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        Tags
)

SELECT 
    t.TagName AS Tag,
    tm.AvgAnswers,
    tm.AvgComments,
    tm.TotalUpVotes,
    tm.TotalDownVotes,
    CASE 
        WHEN tm.TotalUpVotes > tm.TotalDownVotes THEN 'Positive' 
        ELSE 
            CASE 
                WHEN tm.TotalUpVotes < tm.TotalDownVotes THEN 'Negative' 
                ELSE 'Neutral' 
            END 
    END AS Sentiment
FROM 
    Tags t
JOIN 
    TagMetrics tm ON t.TagName = ANY(string_to_array(tm.Tags, ','))
ORDER BY 
    tm.TotalUpVotes DESC, 
    tm.AvgAnswers DESC;
