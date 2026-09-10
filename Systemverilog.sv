module tb_sv;
  function automatic int partition(ref int a[]);
    int pivot;
    int i;
    int j;
    int temp;
    int size1;

    size1 = a.size();
    pivot = a[size1-1];
    i = -1;
    j = 0;
    while (j < size1 - 1) begin
      if (a[j] <= pivot) begin
        i = i + 1;
        temp = a[i];
        a[i] = a[j];
        a[j] = temp;
      end
      j = j + 1;
    end

    temp = a[i+1];
    a[i+1] = a[size1-1];
    a[size1-1] = temp;
  endfunction

  function automatic int max_consecutive_ones(int a[]);
    int count_now;
    int count_max;
    int n;
    int i;

    count_now = 0;
    count_max = 0;
    n = a.size();

    for (i = 0; i < n; i = i + 1) begin
      if (a[i] == 1) begin
        count_now = count_now + 1;
        if (count_now > count_max) begin
          count_max = count_now;
        end
      end
      else begin
        count_now = 0; 
      end
    end

    max_consecutive_ones = count_max;
  endfunction
  function automatic int find_second_max(int a[]);
    int n;
    int i, j;
    int biggest;
    int second;
    int found_first;

    n = a.size();
    biggest = a[0];
    for (i = 0; i < n; i = i + 1) begin
      if (a[i] > biggest) begin
        biggest = a[i];
      end
    end

    second = -2147483648; 
    found_first = 0;
    for (j = 0; j < n; j = j + 1) begin
      if (a[j] != biggest || found_first == 1) begin
        if (a[j] > second && a[j] <= biggest) begin
          if (a[j] != biggest) begin
            second = a[j];
          end
        end
      end
      if (a[j] == biggest) begin
        found_first = 1;
      end
    end

    find_second_max = second;
  endfunction

endmodule