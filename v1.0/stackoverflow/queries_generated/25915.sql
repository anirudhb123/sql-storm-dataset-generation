WITH TagAnalysis AS (
    SELECT 
        t.TagName,
        p.Title AS PostTitle,
        COUNT(*) AS PostCount,
        SUM(v.VoteTypeId = 2) AS TotalUpVotes, -- Upvotes
        SUM(v.VoteTypeId = 3) AS TotalDownVotes, -- Downvotes
        AVG(u.Reputation) AS AvgUserReputation,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT bh.Id) AS HistoryEditCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory bh ON bh.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
    GROUP BY 
        t.TagName, p.Title
),
TagAnalysisFiltered AS (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount,
        SUM(TotalUpVotes) AS TotalUpVotes,
        SUM(TotalDownVotes) AS TotalDownVotes,
        AVG(AvgUserReputation) AS AvgReputation,
        SUM(CommentCount) AS TotalComments,
        SUM(HistoryEditCount) AS TotalEdits
    FROM 
        TagAnalysis
    GROUP BY 
        TagName
),
RankedTags AS (
    SELECT 
        TagName,
        TagUsageCount,
        TotalUpVotes,
        TotalDownVotes,
        AvgReputation,
        TotalComments,
        TotalEdits,
        RANK() OVER (ORDER BY TagUsageCount DESC, TotalUpVotes - TotalDownVotes DESC) AS Rank
    FROM 
        TagAnalysisFiltered
)
SELECT 
    rt.TagName,
    rt.TagUsageCount,
    rt.TotalUpVotes,
    rt.TotalDownVotes,
    rt.AvgReputation,
    rt.TotalComments,
    rt.TotalEdits
FROM 
    RankedTags rt
WHERE 
    rt.Rank <= 10 -- Show top 10 tags
ORDER BY 
    rt.Rank;
