WITH RecursivePostCount AS (
    SELECT 
        P.Id AS PostId, 
        COUNT(*) AS AnswerCount
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2 -- Answers
    GROUP BY 
        P.Id
), RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount,
        MAX(V.CreationDate) AS LastVoteDate 
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= DATEADD(MONTH, -1, GETDATE()) -- Votes in the last month
    GROUP BY 
        V.PostId
), PostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        COALESCE(RP.AnswerCount, 0) AS AnswerCount,
        COALESCE(RV.VoteCount, 0) AS TotalVotes,
        RV.LastVoteDate,
        PH.Comment AS LastEditComment,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        RecursivePostCount RP ON P.Id = RP.PostId
    LEFT JOIN 
        RecentVotes RV ON P.Id = RV.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1 -- Questions
    AND 
        P.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Questions created in the last year
), RankedPosts AS (
    SELECT 
        PD.*,
        ROW_NUMBER() OVER (ORDER BY PD.ViewCount DESC, PD.TotalVotes DESC) AS Rank
    FROM 
        PostDetails PD
)

SELECT 
    RP.PostId, 
    RP.Title, 
    RP.ViewCount, 
    RP.AnswerCount, 
    RP.TotalVotes, 
    RP.LastVoteDate,
    RP.LastEditComment,
    RP.LastEditDate
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 10 -- Top 10 questions
ORDER BY 
    RP.Rank;

### Explanation of the Query:

1. **RecursivePostCount CTE**: This CTE counts the number of answers per post, focusing only on posts of type "Answer".

2. **RecentVotes CTE**: This retrieves the count of votes for posts over the last month, allowing us to measure activity recently.

3. **PostDetails CTE**: Combines information from the previous CTEs with posts of type "Question." It gathers details such as title, view count, number of answers, votes received, and the details of the last edit.

4. **RankedPosts CTE**: Adds a ranking based on view counts and vote counts to order questions by their popularity.

5. **Final SELECT**: Retrieves the top 10 ranked questions and their details.

This query employs various SQL techniques: CTEs, correlation with other tables, window functions, aggregations, and filters to explore the data in depth.
